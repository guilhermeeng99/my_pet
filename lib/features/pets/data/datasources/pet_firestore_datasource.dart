import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/pets/data/models/pet_model.dart';

/// Boundary around `households/{hid}/pets/{petId}` Firestore docs.
abstract class PetFirestoreDatasource {
  Stream<List<PetModel>> watchActive(String householdId);
  Stream<List<PetModel>> watchArchived(String householdId);
  Stream<PetModel?> watchPet(String householdId, String petId);
  Future<PetModel> create(PetModel pet);
  Future<PetModel> update(PetModel pet);
  Future<void> archive(String householdId, String petId);
  Future<void> unarchive(String householdId, String petId);

  /// Patches `pets/{petId}.currentWeightKg`. Used by the weight feature to
  /// cascade the latest weigh-in onto the pet doc without re-writing the
  /// rest of the entity. Pass `null` to clear (e.g. after deleting the
  /// last entry).
  Future<void> setCurrentWeight(
    String householdId,
    String petId,
    double? weightKg,
  );
}

class PetFirestoreDatasourceImpl implements PetFirestoreDatasource {
  PetFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _pets(String householdId) =>
      _firestore.collection('households').doc(householdId).collection('pets');

  @override
  Stream<List<PetModel>> watchActive(String householdId) {
    return _pets(householdId)
        .where('archivedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Stream<List<PetModel>> watchArchived(String householdId) {
    return _pets(householdId)
        .where('archivedAt', isNull: false)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Stream<PetModel?> watchPet(String householdId, String petId) {
    return _pets(householdId).doc(petId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PetModel.fromFirestore(snap.id, snap.data()!);
    });
  }

  @override
  Future<PetModel> create(PetModel pet) async {
    final ref = _pets(pet.householdId).doc();
    final entity = PetModel.fromEntity(pet.copyWith(id: ref.id));
    await ref.set(entity.toFirestoreCreate());
    return entity;
  }

  @override
  Future<PetModel> update(PetModel pet) async {
    await _pets(pet.householdId).doc(pet.id).update(pet.toFirestoreUpdate());
    return pet;
  }

  @override
  Future<void> archive(String householdId, String petId) async {
    await _pets(householdId).doc(petId).update({
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unarchive(String householdId, String petId) async {
    await _pets(householdId).doc(petId).update({
      'archivedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setCurrentWeight(
    String householdId,
    String petId,
    double? weightKg,
  ) async {
    await _pets(householdId).doc(petId).update({
      'currentWeightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<PetModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => PetModel.fromFirestore(d.id, d.data()))
        .toList(growable: false);
  }
}
