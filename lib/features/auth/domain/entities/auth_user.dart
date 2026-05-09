import 'package:equatable/equatable.dart';

/// User identity surfaced from `FirebaseAuth` after a successful Google
/// sign-in. `householdId` is null until the household is created on first
/// sign-in (see [`specs/auth.md`](../../../../../specs/auth.md), rule 3).
class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.householdId,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? householdId;

  bool get hasHousehold => householdId != null;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? householdId,
    bool clearHousehold = false,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      householdId: clearHousehold ? null : (householdId ?? this.householdId),
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, householdId];
}
