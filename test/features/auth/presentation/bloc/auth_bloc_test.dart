import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    // Default stream so the bloc's startup subscription doesn't blow up.
    when(repository.watchAuthState).thenAnswer((_) => const Stream<AuthUser?>.empty());
  });

  AuthBloc buildBloc() => AuthBloc(repository: repository);

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthAuthenticated on successful sign-in when user has household',
      build: () {
        final user = AuthUserFactory.withHousehold();
        when(repository.signInWithGoogle).thenAnswer((_) async => Right(user));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(AuthUserFactory.withHousehold()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthNeedsHousehold when signed-in user has no householdId',
      build: () {
        final user = AuthUserFactory.withoutHousehold();
        when(repository.signInWithGoogle).thenAnswer((_) async => Right(user));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthNeedsHousehold(AuthUserFactory.withoutHousehold()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'cancellation is silent — drops back to Unauthenticated, no error',
      build: () {
        when(repository.signInWithGoogle)
            .thenAnswer((_) async => const Left(AuthCancelledFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'network failure surfaces AuthErrorState',
      build: () {
        when(repository.signInWithGoogle)
            .thenAnswer((_) async => const Left(AuthNetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthErrorState(AuthNetworkFailure()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-out emits Unauthenticated',
      build: () {
        when(repository.signOut).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'auth stream update with null user emits Unauthenticated',
      build: () {
        when(repository.watchAuthState)
            .thenAnswer((_) => Stream<AuthUser?>.value(null));
        return buildBloc();
      },
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
