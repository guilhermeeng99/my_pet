import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/auth/data/models/auth_user_model.dart';

/// Wraps the `users/{uid}` Firestore doc. Repository owns the abstraction
/// so we can mock the boundary in tests.
abstract class UserProfileDatasource {
  Stream<AuthUserModel?> watch(String uid);
  Future<AuthUserModel?> read(String uid);
  Future<void> upsert(AuthUserModel user);
  Future<void> setHousehold(String uid, String householdId);
}

class UserProfileDatasourceImpl implements UserProfileDatasource {
  UserProfileDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AuthUserModel?> watch(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AuthUserModel.fromFirestore(snap.id, snap.data()!);
    });
  }

  @override
  Future<AuthUserModel?> read(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AuthUserModel.fromFirestore(snap.id, snap.data()!);
  }

  @override
  Future<void> upsert(AuthUserModel user) async {
    await _users.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> setHousehold(String uid, String householdId) async {
    await _users.doc(uid).set({'householdId': householdId}, SetOptions(merge: true));
  }
}
