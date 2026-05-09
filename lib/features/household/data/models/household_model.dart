import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/household/domain/entities/household.dart';

/// Firestore <-> Household converter. Models extend entities and handle
/// serialization (CLAUDE.md / Code Conventions).
class HouseholdModel extends Household {
  const HouseholdModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.memberIds,
    required super.createdAt,
  });

  factory HouseholdModel.fromFirestore(String id, Map<String, dynamic> data) {
    return HouseholdModel(
      id: id,
      name: (data['name'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      memberIds: List<String>.from((data['memberIds'] ?? <String>[]) as List),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
