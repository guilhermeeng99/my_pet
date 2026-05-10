import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/documents/data/models/pet_document_model.dart';

abstract class DocumentFirestoreDatasource {
  Stream<List<PetDocumentModel>> watchByHousehold(String householdId);
  Stream<List<PetDocumentModel>> watchByPet(String householdId, String petId);
  Future<PetDocumentModel> create(PetDocumentModel document);
  Future<PetDocumentModel> update(PetDocumentModel document);
  Future<void> delete(String householdId, String documentId);
}

class DocumentFirestoreDatasourceImpl implements DocumentFirestoreDatasource {
  DocumentFirestoreDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(String hid) =>
      _firestore
          .collection('households')
          .doc(hid)
          .collection('documents');

  @override
  Stream<List<PetDocumentModel>> watchByHousehold(String hid) {
    return _coll(hid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetDocumentModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Stream<List<PetDocumentModel>> watchByPet(String hid, String petId) {
    return _coll(hid)
        .where('petId', isEqualTo: petId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetDocumentModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Future<PetDocumentModel> create(PetDocumentModel document) async {
    final ref = _coll(document.householdId).doc(document.id);
    await ref.set(document.toFirestoreCreate());
    return document;
  }

  @override
  Future<PetDocumentModel> update(PetDocumentModel document) async {
    final ref = _coll(document.householdId).doc(document.id);
    await ref.update(document.toFirestoreUpdate());
    return document;
  }

  @override
  Future<void> delete(String hid, String documentId) async {
    await _coll(hid).doc(documentId).delete();
  }
}
