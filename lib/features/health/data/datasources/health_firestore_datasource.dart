import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/health/data/models/health_event_model.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';

abstract class HealthFirestoreDatasource {
  Stream<List<HealthEventModel>> watchByPet(String householdId, String petId);
  Stream<List<HealthEventModel>> watchByPetAndType(
    String householdId,
    String petId,
    HealthEventType type,
  );
  Future<HealthEventModel> create(HealthEventModel event);
  Future<HealthEventModel> update(HealthEventModel event);
  Future<void> delete(String householdId, String petId, String eventId);
}

class HealthFirestoreDatasourceImpl implements HealthFirestoreDatasource {
  HealthFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(
    String hid,
    String petId,
  ) =>
      _firestore
          .collection('households')
          .doc(hid)
          .collection('pets')
          .doc(petId)
          .collection('health_events');

  @override
  Stream<List<HealthEventModel>> watchByPet(String hid, String petId) {
    return _coll(hid, petId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Stream<List<HealthEventModel>> watchByPetAndType(
    String hid,
    String petId,
    HealthEventType type,
  ) {
    return _coll(hid, petId)
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Future<HealthEventModel> create(HealthEventModel event) async {
    final ref = _coll(event.householdId, event.petId).doc();
    final assigned = HealthEventModel.fromEntity(event.copyWith(id: ref.id));
    await ref.set(assigned.toFirestoreCreate());
    return assigned;
  }

  @override
  Future<HealthEventModel> update(HealthEventModel event) async {
    final ref = _coll(event.householdId, event.petId).doc(event.id);
    await ref.update(event.toFirestoreUpdate());
    return event;
  }

  @override
  Future<void> delete(String hid, String petId, String eventId) async {
    await _coll(hid, petId).doc(eventId).delete();
  }

  List<HealthEventModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => HealthEventModel.fromFirestore(d.id, d.data()))
        .toList(growable: false);
  }
}
