import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:my_pet/features/auth/data/datasources/user_profile_datasource.dart';
import 'package:my_pet/features/auth/data/models/auth_user_model.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDatasource auth,
    required UserProfileDatasource profiles,
  })  : _auth = auth,
        _profiles = profiles;

  final FirebaseAuthDatasource _auth;
  final UserProfileDatasource _profiles;

  @override
  Stream<AuthUser?> watchAuthState() {
    // Listen to both Firebase Auth (sign-in/out) AND the user's Firestore
    // profile doc so household joins, role changes and remote profile edits
    // propagate to the UI without manual refresh events. `asyncExpand` cancels
    // the inner profile stream whenever the outer auth user changes.
    return _auth.watchUser().asyncExpand<AuthUser?>((fbUser) {
      if (fbUser == null) return Stream<AuthUser?>.value(null);
      return _watchProfileWithFallback(fbUser);
    });
  }

  Stream<AuthUser?> _watchProfileWithFallback(fb.User fbUser) async* {
    // Wait for the first profile snapshot before emitting — yielding the raw
    // Firebase entity first would briefly route returning users (who have a
    // householdId) through the AuthNeedsHousehold setup screen.
    //
    // Heal pass (`healAttempted`): if the Firestore doc lacks fields that
    // Firebase Auth carries (email, displayName, photoUrl), upsert the
    // missing ones once per stream session. Reproducer: a prior
    // account-deletion path failed with requires-recent-login — Firestore
    // was wiped but Firebase Auth survived — then `createAndLinkToUser`
    // recreated the user doc with only `{householdId}`. Without healing,
    // the Profile identity card renders blank because `fetchMembers`
    // reads the bare doc.
    try {
      var healAttempted = false;
      await for (final profile in _profiles.watch(fbUser.uid)) {
        if (profile == null) {
          yield _entityFromFirebase(fbUser);
          continue;
        }
        if (!healAttempted && _profileNeedsHeal(profile, fbUser)) {
          healAttempted = true;
          final healed = await _healProfile(profile, fbUser);
          if (healed) {
            // The upsert produces a new snapshot on the same subscription;
            // skip emitting the stale one so the UI never flashes empty
            // identity fields.
            continue;
          }
          // Heal failed (rules / network) — synthesize a merged entity so
          // the AuthBloc still sees good data even though the Firestore
          // doc remains incomplete.
          yield _mergeProfile(profile, fbUser);
          continue;
        }
        yield profile;
      }
    } on Object catch (e, st) {
      developer.log(
        'Profile stream failed for ${fbUser.uid}; falling back to Firebase entity',
        name: 'auth',
        error: e,
        stackTrace: st,
      );
      yield _entityFromFirebase(fbUser);
    }
  }

  bool _profileNeedsHeal(AuthUserModel profile, fb.User fbUser) {
    if (profile.email.isEmpty && (fbUser.email?.isNotEmpty ?? false)) {
      return true;
    }
    if (profile.displayName == null &&
        (fbUser.displayName?.isNotEmpty ?? false)) {
      return true;
    }
    if (profile.photoUrl == null && (fbUser.photoURL?.isNotEmpty ?? false)) {
      return true;
    }
    return false;
  }

  Future<bool> _healProfile(AuthUserModel profile, fb.User fbUser) async {
    try {
      // Preserve the existing createdAt so the heal doesn't bump the
      // server timestamp; only fill the gaps Firebase Auth can answer.
      final healed = AuthUserModel(
        uid: profile.uid,
        email: profile.email.isEmpty ? (fbUser.email ?? '') : profile.email,
        displayName: profile.displayName ?? fbUser.displayName,
        photoUrl: profile.photoUrl ?? fbUser.photoURL,
        householdId: profile.householdId,
        createdAt: profile.createdAt,
      );
      await _profiles.upsert(healed);
      return true;
    } on Object catch (e, st) {
      developer.log(
        'Failed to heal incomplete user profile for ${fbUser.uid}',
        name: 'auth',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  AuthUser _mergeProfile(AuthUserModel profile, fb.User fbUser) {
    return AuthUser(
      uid: profile.uid,
      email: profile.email.isEmpty ? (fbUser.email ?? '') : profile.email,
      displayName: profile.displayName ?? fbUser.displayName,
      photoUrl: profile.photoUrl ?? fbUser.photoURL,
      householdId: profile.householdId,
    );
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final fbUser = await _auth.signInWithGoogle();
      // Persist (or refresh) the user profile. New users have no document
      // yet — the upsert creates it; existing users keep their householdId.
      final existing = await _profiles.read(fbUser.uid);
      final entity = _entityFromFirebase(fbUser).copyWith(
        householdId: existing?.householdId,
      );
      await _profiles.upsert(AuthUserModel.fromEntity(entity));
      return Right(entity);
    } on fb.FirebaseAuthException catch (e, st) {
      if (_isNetwork(e)) {
        return Left(AuthNetworkFailure(cause: e));
      }
      return Left(AuthUnknownFailure(message: e.message, cause: st));
    } on SocketException catch (e) {
      return Left(AuthNetworkFailure(cause: e));
    } on Exception catch (e, st) {
      if (_isCancellation(e)) {
        return const Left(AuthCancelledFailure());
      }
      return Left(AuthUnknownFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(unit);
    } on Exception catch (e, st) {
      return Left(AuthUnknownFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCurrentAccount() async {
    try {
      await _auth.deleteCurrentUser();
      return const Right(unit);
    } on fb.FirebaseAuthException catch (e, st) {
      if (e.code == 'requires-recent-login') {
        return const Left(RequiresRecentLoginFailure());
      }
      return Left(AuthUnknownFailure(message: e.message, cause: st));
    } on Exception catch (e, st) {
      return Left(AuthUnknownFailure(message: e.toString(), cause: st));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      return const Left(NotFoundFailure(message: 'No user signed in.'));
    }
    try {
      final profile = await _profiles.read(fbUser.uid);
      return Right(profile ?? _entityFromFirebase(fbUser));
    } on Exception catch (e, st) {
      return Left(ServerFailure(message: e.toString(), cause: st));
    }
  }

  AuthUser _entityFromFirebase(fb.User fbUser) {
    return AuthUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName,
      photoUrl: fbUser.photoURL,
    );
  }

  bool _isCancellation(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('cancel');
  }

  bool _isNetwork(fb.FirebaseAuthException e) {
    return e.code == 'network-request-failed';
  }
}
