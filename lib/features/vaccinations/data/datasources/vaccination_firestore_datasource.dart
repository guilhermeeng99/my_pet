import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/vaccinations/data/models/vaccination_model.dart';

abstract class VaccinationFirestoreDatasource {
  Stream<List<VaccinationModel>> watchByPet(String householdId, String petId);
  Future<VaccinationModel> create(VaccinationModel vaccination);
  Future<VaccinationModel> update(VaccinationModel vaccination);
  Future<void> delete(String householdId, String petId, String vaccinationId);
}

class VaccinationFirestoreDatasourceImpl
    implements VaccinationFirestoreDatasource {
  VaccinationFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(String hid, String petId) =>
      _firestore
          .collection('households')
          .doc(hid)
          .collection('pets')
          .doc(petId)
          .collection('vaccinations');

  @override
  Stream<List<VaccinationModel>> watchByPet(String householdId, String petId) {
    return _coll(householdId, petId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => VaccinationModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Future<VaccinationModel> create(VaccinationModel vaccination) async {
    final ref = _coll(vaccination.householdId, vaccination.petId).doc();
    final entity = VaccinationModel.fromEntity(vaccination.copyWith(id: ref.id));
    await ref.set(entity.toFirestoreCreate());
    return entity;
  }

  @override
  Future<VaccinationModel> update(VaccinationModel vaccination) async {
    await _coll(vaccination.householdId, vaccination.petId)
        .doc(vaccination.id)
        .update(vaccination.toFirestoreUpdate());
    return vaccination;
  }

  @override
  Future<void> delete(String householdId, String petId, String vaccinationId) {
    return _coll(householdId, petId).doc(vaccinationId).delete();
  }
}
