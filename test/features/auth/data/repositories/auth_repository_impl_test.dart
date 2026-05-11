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

  group('watchAuthState — profile heal', () {
    test(
      'upserts missing email/displayName/photoUrl from Firebase Auth when '
      'the Firestore doc was created with only {householdId}',
      () async {
        final fbUser = stubFirebaseUser(
          photoUrl: 'https://avatar.example/jane.png',
        );
        when(() => auth.watchUser())
            .thenAnswer((_) => Stream<fb.User?>.value(fbUser));
        // Bug repro: prior account-deletion wiped the user doc; the
        // subsequent createAndLinkToUser wrote a doc with only the link.
        const bare = AuthUserModel(
          uid: 'uid_123',
          email: '',
          householdId: 'household_42',
        );
        // After heal completes, Firestore will fire a fresh snapshot with
        // the merged fields. The repository must consume the stale tick
        // silently and only emit the healed one.
        const healed = AuthUserModel(
          uid: 'uid_123',
          email: 'jane@example.com',
          displayName: 'Jane',
          photoUrl: 'https://avatar.example/jane.png',
          householdId: 'household_42',
        );
        when(() => profiles.watch('uid_123')).thenAnswer(
          (_) => Stream<AuthUserModel?>.fromIterable([bare, healed]),
        );
        when(() => profiles.upsert(any())).thenAnswer((_) async {});

        final emitted = await repository.watchAuthState().toList();

        // Only the healed snapshot reaches AuthBloc — the bare one is
        // swallowed while the upsert lands.
        expect(emitted, hasLength(1));
        expect(emitted.single?.email, 'jane@example.com');
        expect(emitted.single?.displayName, 'Jane');
        expect(emitted.single?.photoUrl, 'https://avatar.example/jane.png');
        expect(emitted.single?.householdId, 'household_42');

        final captured =
            verify(() => profiles.upsert(captureAny())).captured.single
                as AuthUserModel;
        expect(captured.email, 'jane@example.com');
        expect(captured.displayName, 'Jane');
        expect(captured.photoUrl, 'https://avatar.example/jane.png');
        expect(captured.householdId, 'household_42');
      },
    );

    test('does not heal when the Firestore profile already carries '
        'email and displayName', () async {
      final fbUser = stubFirebaseUser();
      when(() => auth.watchUser())
          .thenAnswer((_) => Stream<fb.User?>.value(fbUser));
      const complete = AuthUserModel(
        uid: 'uid_123',
        email: 'jane@example.com',
        displayName: 'Jane',
        householdId: 'household_42',
      );
      when(() => profiles.watch('uid_123')).thenAnswer(
        (_) => Stream<AuthUserModel?>.value(complete),
      );

      final emitted = await repository.watchAuthState().toList();

      expect(emitted, hasLength(1));
      expect(emitted.single?.email, 'jane@example.com');
      verifyNever(() => profiles.upsert(any()));
    });

    test('emits a merged fallback entity when the heal upsert itself fails',
        () async {
      final fbUser = stubFirebaseUser();
      when(() => auth.watchUser())
          .thenAnswer((_) => Stream<fb.User?>.value(fbUser));
      const bare = AuthUserModel(
        uid: 'uid_123',
        email: '',
        householdId: 'household_42',
      );
      when(() => profiles.watch('uid_123')).thenAnswer(
        (_) => Stream<AuthUserModel?>.value(bare),
      );
      when(() => profiles.upsert(any()))
          .thenThrow(Exception('rules rejected the write'));

      final emitted = await repository.watchAuthState().toList();

      expect(emitted, hasLength(1));
      // Fallback merge fills the empty fields from Firebase Auth so the
      // UI never sees a blank identity even if the doc stays incomplete.
      expect(emitted.single?.email, 'jane@example.com');
      expect(emitted.single?.displayName, 'Jane');
      expect(emitted.single?.householdId, 'household_42');
    });

    test('falls back to the Firebase entity when no profile doc exists yet',
        () async {
      final fbUser = stubFirebaseUser();
      when(() => auth.watchUser())
          .thenAnswer((_) => Stream<fb.User?>.value(fbUser));
      when(() => profiles.watch('uid_123'))
          .thenAnswer((_) => Stream<AuthUserModel?>.value(null));

      final emitted = await repository.watchAuthState().toList();

      expect(emitted, hasLength(1));
      expect(emitted.single?.email, 'jane@example.com');
      expect(emitted.single?.householdId, isNull);
      verifyNever(() => profiles.upsert(any()));
    });
  });
}
