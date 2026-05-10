import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/gallery/domain/entities/pet_photo.dart';

class PetPhotoModel extends PetPhoto {
  const PetPhotoModel({
    required super.id,
    required super.householdId,
    required super.petId,
    required super.url,
    required super.thumbnailUrl,
    required super.createdAt,
    required super.createdBy,
    super.caption,
    super.takenAt,
  });

  factory PetPhotoModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return PetPhotoModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: (data['petId'] ?? '') as String,
      url: (data['url'] ?? '') as String,
      thumbnailUrl: (data['thumbnailUrl'] ?? '') as String,
      caption: data['caption'] as String?,
      takenAt: ts('takenAt'),
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  PetPhotoModel.fromEntity(PetPhoto p)
      : super(
          id: p.id,
          householdId: p.householdId,
          petId: p.petId,
          url: p.url,
          thumbnailUrl: p.thumbnailUrl,
          caption: p.caption,
          takenAt: p.takenAt,
          createdAt: p.createdAt,
          createdBy: p.createdBy,
        );

  Map<String, dynamic> toFirestoreCreate() {
    final map = _toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toFirestoreUpdate() => _toMap()..remove('createdAt');

  Map<String, dynamic> _toMap() {
    return {
      'householdId': householdId,
      'petId': petId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'takenAt': takenAt == null ? null : Timestamp.fromDate(takenAt!),
      'createdBy': createdBy,
    };
  }
}
