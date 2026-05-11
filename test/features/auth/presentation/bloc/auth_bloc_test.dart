import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late MockHouseholdRepository households;
  late MockSessionScope sessionScope;

  setUpAll(() {
    // Mocktail requires fallbacks to exist before any() is referenced.
    registerFallbackValue(AuthUserFactory.withoutHousehold());
  });

  setUp(() {
    repository = MockAuthRepository();
    households = MockHouseholdRepository();
    sessionScope = MockSessionScope();

    // Default stream so the bloc's startup subscription doesn't blow up.
    when(repository.watchAuthState)
        .thenAnswer((_) => const Stream<AuthUser?>.empty());

    // Default household auto-create — individual tests override when needed.
    when(() => households.createForUser(any()))
        .thenAnswer((_) async => Right(HouseholdFactory.build()));

    // Sign-out path always tears down session-scoped singletons.
    when(sessionScope.reset).thenAnswer((_) async {});
  });

  AuthBloc buildBloc() => AuthBloc(
        repository: repository,
        householdRepository: households,
        sessionScope: sessionScope,
      );

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
      'first sign-in lands on NeedsHousehold (no auto-create)',
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
      verify: (_) {
        // Auto-create was removed in favor of explicit setup choice.
        verifyNever(() => households.createForUser(any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'CreateOwnHouseholdRequested: NeedsHousehold -> Creating -> Authenticated',
      build: () {
        final user = AuthUserFactory.withoutHousehold();
        when(repository.signInWithGoogle).thenAnswer((_) async => Right(user));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const GoogleSignInRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CreateOwnHouseholdRequested());
      },
      expect: () => [
        const AuthLoading(),
        AuthNeedsHousehold(AuthUserFactory.withoutHousehold()),
        AuthCreatingHousehold(AuthUserFactory.withoutHousehold()),
        AuthAuthenticated(
          AuthUserFactory.withoutHousehold().copyWith(householdId: 'household_42'),
        ),
      ],
      verify: (_) {
        verify(() => households.createForUser(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'CreateOwnHouseholdRequested failure surfaces AuthErrorState',
      build: () {
        final user = AuthUserFactory.withoutHousehold();
        when(repository.signInWithGoogle).thenAnswer((_) async => Right(user));
        when(() => households.createForUser(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'boom')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const GoogleSignInRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CreateOwnHouseholdRequested());
      },
      expect: () => [
        const AuthLoading(),
        AuthNeedsHousehold(AuthUserFactory.withoutHousehold()),
        AuthCreatingHousehold(AuthUserFactory.withoutHousehold()),
        const AuthErrorState(ServerFailure(message: 'boom')),
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
      'sign-out emits Unauthenticated and resets the session scope',
      build: () {
        when(repository.signOut).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        // Session-scoped singletons (PetsListCubit's stream, etc.) must be
        // torn down before the next sign-in to avoid stale data leaks.
        verify(sessionScope.reset).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'sign-out failure surfaces error and does NOT reset session',
      build: () {
        when(repository.signOut).thenAnswer(
          (_) async => const Left(AuthUnknownFailure(message: 'boom')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [const AuthErrorState(AuthUnknownFailure(message: 'boom'))],
      verify: (_) {
        verifyNever(sessionScope.reset);
      },
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
