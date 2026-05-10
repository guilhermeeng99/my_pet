import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/household/domain/entities/invite.dart';

class InviteModel extends Invite {
  const InviteModel({
    required super.code,
    required super.householdId,
    required super.createdBy,
    required super.createdAt,
    required super.expiresAt,
    super.usedBy,
  });

  factory InviteModel.fromFirestore(String code, Map<String, dynamic> data) {
    return InviteModel(
      code: code,
      householdId: (data['householdId'] ?? '') as String,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
      usedBy: data['usedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'householdId': householdId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'usedBy': null,
    };
  }
}
