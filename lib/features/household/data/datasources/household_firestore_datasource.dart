import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/household/data/models/household_model.dart';

/// Project-owned wrapper around the `households/{id}` Firestore docs and
/// the cross-cutting `users/{uid}.householdId` write. The repository
/// depends on this abstraction so the boundary is mockable.
abstract class HouseholdFirestoreDatasource {
  Stream<HouseholdModel?> watch(String householdId);

  /// Creates a household and links it to the user's profile in one batched
  /// write — household.md rule 5.3.
  Future<HouseholdModel> createAndLinkToUser({
    required String userId,
    required String name,
  });
}

class HouseholdFirestoreDatasourceImpl implements HouseholdFirestoreDatasource {
  HouseholdFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<HouseholdModel?> watch(String householdId) {
    return _firestore.collection('households').doc(householdId).snapshots().map(
      (snap) {
        if (!snap.exists) return null;
        return HouseholdModel.fromFirestore(snap.id, snap.data()!);
      },
    );
  }

  @override
  Future<HouseholdModel> createAndLinkToUser({
    required String userId,
    required String name,
  }) async {
    final householdRef = _firestore.collection('households').doc();
    final userRef = _firestore.collection('users').doc(userId);

    await (_firestore.batch()
          ..set(householdRef, {
            'name': name,
            'ownerId': userId,
            'memberIds': [userId],
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(
            userRef,
            {'householdId': householdRef.id},
            SetOptions(merge: true),
          ))
        .commit();

    return HouseholdModel(
      id: householdRef.id,
      name: name,
      ownerId: userId,
      memberIds: [userId],
      createdAt: DateTime.now().toUtc(),
    );
  }
}
