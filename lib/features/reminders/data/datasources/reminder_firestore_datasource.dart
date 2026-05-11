import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/reminders/data/models/reminder_model.dart';

abstract class ReminderFirestoreDatasource {
  Stream<List<ReminderModel>> watchActive(String householdId);
  Stream<List<ReminderModel>> watchByPet(String householdId, String petId);
  Future<ReminderModel> create(ReminderModel reminder);
  Future<ReminderModel> update(ReminderModel reminder);
  Future<void> delete(String householdId, String reminderId);
}

class ReminderFirestoreDatasourceImpl implements ReminderFirestoreDatasource {
  ReminderFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('reminders');

  @override
  Stream<List<ReminderModel>> watchActive(String householdId) {
    return _coll(householdId)
        .where('done', isEqualTo: false)
        .orderBy('dueAt')
        .limit(AppConstants.activeRemindersLimit)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Stream<List<ReminderModel>> watchByPet(
    String householdId,
    String petId,
  ) {
    return _coll(householdId)
        .where('done', isEqualTo: false)
        .where('petId', isEqualTo: petId)
        .orderBy('dueAt')
        .limit(AppConstants.activeRemindersLimit)
        .snapshots()
        .map(_mapDocs);
  }

  @override
  Future<ReminderModel> create(ReminderModel reminder) async {
    final ref = _coll(reminder.householdId).doc();
    final assigned = ReminderModel.fromEntity(reminder.copyWith(id: ref.id));
    await ref.set(assigned.toFirestoreCreate());
    return assigned;
  }

  @override
  Future<ReminderModel> update(ReminderModel reminder) async {
    final ref = _coll(reminder.householdId).doc(reminder.id);
    await ref.update(reminder.toFirestoreUpdate());
    return reminder;
  }

  @override
  Future<void> delete(String householdId, String reminderId) async {
    await _coll(householdId).doc(reminderId).delete();
  }

  List<ReminderModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => ReminderModel.fromFirestore(d.id, d.data()))
        .toList(growable: false);
  }
}
