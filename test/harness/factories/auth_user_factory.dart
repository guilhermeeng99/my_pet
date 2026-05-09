import 'package:my_pet/features/auth/domain/entities/auth_user.dart';

/// Factory for [AuthUser] used in tests. Never hardcode entities in tests
/// (CLAUDE.md / Test Structure).
class AuthUserFactory {
  static AuthUser build({
    String uid = 'uid_123',
    String email = 'jane@example.com',
    String? displayName = 'Jane Doe',
    String? photoUrl,
    String? householdId,
  }) {
    return AuthUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      householdId: householdId,
    );
  }

  static AuthUser withHousehold({String householdId = 'household_42'}) {
    return build(householdId: householdId);
  }

  static AuthUser withoutHousehold() => build();
}
