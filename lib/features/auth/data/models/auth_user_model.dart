import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/auth/domain/entities/auth_user.dart';

/// Firestore-aware extension of [AuthUser]. Models extend entities and
/// handle serialization (CLAUDE.md / Code Conventions).
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.householdId,
    this.createdAt,
  });

  factory AuthUserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AuthUserModel(
      uid: id,
      email: (data['email'] ?? '') as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      householdId: data['householdId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  AuthUserModel.fromEntity(AuthUser user)
      : createdAt = null,
        super(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          householdId: user.householdId,
        );

  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (householdId != null) 'householdId': householdId,
      // Server timestamp is preserved across updates because we set it only
      // when the doc is brand new — see [AuthRepositoryImpl] / first sign-in.
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
