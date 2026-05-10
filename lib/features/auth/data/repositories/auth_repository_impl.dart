import 'dart:async';
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
    return _auth.watchUser().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      // Try to enrich with the persisted profile (mostly to learn the
      // householdId). On read failure we still surface the raw Firebase
      // user — auth state must keep flowing even if Firestore hiccups.
      try {
        final profile = await _profiles.read(fbUser.uid);
        return profile ?? _entityFromFirebase(fbUser);
      } on Exception {
        return _entityFromFirebase(fbUser);
      }
    });
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
