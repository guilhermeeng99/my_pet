import 'package:equatable/equatable.dart';

/// Short-lived invite code that lets a second user join a household. The
/// document id at `inviteCodes/{code}` IS the code, so a signed-in user can
/// look it up before becoming a member. See
/// [`docs/specs/household.md`](../../../../../docs/specs/household.md).
class Invite extends Equatable {
  const Invite({
    required this.code,
    required this.householdId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.usedBy,
  });

  final String code;
  final String householdId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? usedBy;

  bool get isUsed => usedBy != null;
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
  bool isActive(DateTime now) => !isUsed && !isExpired(now);

  @override
  List<Object?> get props =>
      [code, householdId, createdBy, createdAt, expiresAt, usedBy];
}
