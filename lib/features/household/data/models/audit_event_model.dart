import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/household/domain/entities/audit_event.dart';

class AuditEventModel extends AuditEvent {
  const AuditEventModel({
    required super.id,
    required super.householdId,
    required super.action,
    required super.actorId,
    required super.actorName,
    required super.at,
    super.targetUserId,
    super.targetName,
    super.note,
  });

  factory AuditEventModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AuditEventModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      action: _actionFromString(data['action'] as String?),
      actorId: (data['actorId'] ?? '') as String,
      actorName: (data['actorName'] ?? '') as String,
      targetUserId: data['targetUserId'] as String?,
      targetName: data['targetName'] as String?,
      at: (data['at'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'householdId': householdId,
      'action': action.name,
      'actorId': actorId,
      'actorName': actorName,
      'targetUserId': targetUserId,
      'targetName': targetName,
      'at': FieldValue.serverTimestamp(),
      'note': note,
    };
  }

  static AuditAction _actionFromString(String? raw) =>
      AuditAction.values.firstWhere(
        (a) => a.name == raw,
        orElse: () => AuditAction.householdRenamed,
      );
}
