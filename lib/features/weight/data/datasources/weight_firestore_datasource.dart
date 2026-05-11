import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/weight/data/models/weight_entry_model.dart';

abstract class WeightFirestoreDatasource {
  Stream<List<WeightEntryModel>> watchByPet(
    String householdId,
    String petId,
  );
  Future<WeightEntryModel> create(WeightEntryModel entry);
  Future<WeightEntryModel> update(WeightEntryModel entry);
  Future<void> delete(String householdId, String petId, String entryId);
}

class WeightFirestoreDatasourceImpl implements WeightFirestoreDatasource {
  WeightFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(
    String householdId,
    String petId,
  ) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('pets')
          .doc(petId)
          .collection('weights');

  @override
  Stream<List<WeightEntryModel>> watchByPet(
    String householdId,
    String petId,
  ) {
    return _coll(householdId, petId)
        .orderBy('date', descending: true)
        .limit(AppConstants.historyPageLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WeightEntryModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Future<WeightEntryModel> create(WeightEntryModel entry) async {
    final ref = _coll(entry.householdId, entry.petId).doc();
    final assigned = WeightEntryModel.fromEntity(entry.copyWith(id: ref.id));
    await ref.set(assigned.toFirestoreCreate());
    return assigned;
  }

  @override
  Future<WeightEntryModel> update(WeightEntryModel entry) async {
    final ref = _coll(entry.householdId, entry.petId).doc(entry.id);
    await ref.update(entry.toFirestoreUpdate());
    return entry;
  }

  @override
  Future<void> delete(
    String householdId,
    String petId,
    String entryId,
  ) async {
    await _coll(householdId, petId).doc(entryId).delete();
  }
}
