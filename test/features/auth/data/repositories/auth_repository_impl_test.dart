import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/data/models/auth_user_model.dart';
import 'package:my_pet/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../harness/mocks.dart';

class _MockFirebaseUser extends Mock implements fb.User {}

void main() {
  late MockFirebaseAuthDatasource auth;
  late MockUserProfileDatasource profiles;
  late AuthRepositoryImpl repository;

  setUp(() {
    auth = MockFirebaseAuthDatasource();
    profiles = MockUserProfileDatasource();
    repository = AuthRepositoryImpl(auth: auth, profiles: profiles);

    registerFallbackValue(
      const AuthUserModel(uid: 'fallback', email: 'fallback@example.com'),
    );
  });

  fb.User stubFirebaseUser({
    String uid = 'uid_123',
    String email = 'jane@example.com',
    String? displayName = 'Jane',
    String? photoUrl,
  }) {
    final user = _MockFirebaseUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.photoURL).thenReturn(photoUrl);
    return user;
  }

  group('signInWithGoogle', () {
    test('returns AuthUser with householdId when profile already exists', () async {
      final fbUser = stubFirebaseUser();
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => fbUser);
      when(() => profiles.read('uid_123')).thenAnswer(
        (_) async => const AuthUserModel(
          uid: 'uid_123',
          email: 'jane@example.com',
          householdId: 'household_42',
        ),
      );
      when(() => profiles.upsert(any())).thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (user) => expect(user.householdId, 'household_42'),
      );
    });

    test('returns AuthUser without householdId on first sign-in', () async {
      final fbUser = stubFirebaseUser();
      when(() => auth.signInWithGoogle()).thenAnswer((_) async => fbUser);
      when(() => profiles.read('uid_123')).thenAnswer((_) async => null);
      when(() => profiles.upsert(any())).thenAnswer((_) async {});

      final result = await repository.signInWithGoogle();

      result.fold(
        (_) => fail('expected Right'),
        (user) {
          expect(user.householdId, isNull);
          expect(user.hasHousehold, isFalse);
        },
      );
      verify(() => profiles.upsert(any())).called(1);
    });

    test('maps cancellation exception to AuthCancelledFailure', () async {
      when(() => auth.signInWithGoogle())
          .thenThrow(Exception('Sign-in canceled by user'));

      final result = await repository.signInWithGoogle();

      expect(result, const Left<Failure, dynamic>(AuthCancelledFailure()));
    });

    test('maps network FirebaseAuthException to AuthNetworkFailure', () async {
      when(() => auth.signInWithGoogle()).thenThrow(
        fb.FirebaseAuthException(code: 'network-request-failed'),
      );

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthNetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('signOut', () {
    test('returns Unit on success', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});
      final result = await repository.signOut();
      expect(result, const Right<Failure, Unit>(unit));
    });
  });
}
