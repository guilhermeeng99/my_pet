import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/gallery/data/models/pet_photo_model.dart';

abstract class GalleryFirestoreDatasource {
  Stream<List<PetPhotoModel>> watchByPet(String householdId, String petId);
  Future<PetPhotoModel> create(PetPhotoModel photo);
  Future<PetPhotoModel> update(PetPhotoModel photo);
  Future<void> delete(String householdId, String petId, String photoId);
  Future<int> countForPet(String householdId, String petId);
}

class GalleryFirestoreDatasourceImpl implements GalleryFirestoreDatasource {
  GalleryFirestoreDatasourceImpl({required FirebaseFirestore firestore})
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
          .collection('photos');

  @override
  Stream<List<PetPhotoModel>> watchByPet(String hid, String petId) {
    return _coll(hid, petId)
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PetPhotoModel.fromFirestore(d.id, d.data()))
            .toList(growable: false));
  }

  @override
  Future<PetPhotoModel> create(PetPhotoModel photo) async {
    final ref = _coll(photo.householdId, photo.petId).doc(photo.id);
    await ref.set(photo.toFirestoreCreate());
    return photo;
  }

  @override
  Future<PetPhotoModel> update(PetPhotoModel photo) async {
    final ref = _coll(photo.householdId, photo.petId).doc(photo.id);
    await ref.update(photo.toFirestoreUpdate());
    return photo;
  }

  @override
  Future<void> delete(String hid, String petId, String photoId) async {
    await _coll(hid, petId).doc(photoId).delete();
  }

  @override
  Future<int> countForPet(String hid, String petId) async {
    final snap = await _coll(hid, petId).count().get();
    return snap.count ?? 0;
  }
}
