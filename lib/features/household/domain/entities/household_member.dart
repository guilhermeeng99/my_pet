import 'package:equatable/equatable.dart';

/// Read-model that joins `users/{uid}` profile data with the role inside the
/// household. Built by the repository when fetching members.
enum HouseholdRole { owner, partner }

class HouseholdMember extends Equatable {
  const HouseholdMember({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final HouseholdRole role;
  final String? displayName;
  final String? photoUrl;

  bool get isOwner => role == HouseholdRole.owner;

  @override
  List<Object?> get props => [uid, email, role, displayName, photoUrl];
}
