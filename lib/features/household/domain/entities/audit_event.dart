import 'package:equatable/equatable.dart';

/// Minimal audit trail for household management actions.
///
/// Lives at `households/{hid}/audit/{eventId}`. We use a fixed
/// vocabulary so historical entries stay parseable even if the UI
/// evolves; new actions append to [AuditAction].
enum AuditAction {
  householdCreated,
  inviteGenerated,
  inviteAccepted,
  memberRemoved,
  memberLeft,
  ownerTransferred,
  householdRenamed,
}

class AuditEvent extends Equatable {
  const AuditEvent({
    required this.id,
    required this.householdId,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.targetUserId,
    this.targetName,
    this.note,
  });

  final String id;
  final String householdId;
  final AuditAction action;

  /// UID of the user who performed the action. Mirrors `actorName` so the
  /// list can render without an extra profile lookup.
  final String actorId;
  final String actorName;

  /// UID of the user affected by the action (e.g. the removed partner).
  final String? targetUserId;
  final String? targetName;
  final DateTime at;
  final String? note;

  @override
  List<Object?> get props => [
        id,
        householdId,
        action,
        actorId,
        actorName,
        targetUserId,
        targetName,
        at,
        note,
      ];
}
