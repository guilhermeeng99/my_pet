import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/documents/domain/entities/document_category.dart';
import 'package:my_pet/features/documents/domain/entities/pet_document.dart';

class PetDocumentModel extends PetDocument {
  const PetDocumentModel({
    required super.id,
    required super.householdId,
    required super.title,
    required super.category,
    required super.fileUrl,
    required super.mimeType,
    required super.sizeBytes,
    required super.createdAt,
    required super.createdBy,
    super.petId,
    super.notes,
  });

  factory PetDocumentModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return PetDocumentModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: data['petId'] as String?,
      title: (data['title'] ?? '') as String,
      category: _categoryFromString(data['category'] as String?),
      fileUrl: (data['fileUrl'] ?? '') as String,
      mimeType: (data['mimeType'] ?? 'application/octet-stream') as String,
      sizeBytes: (data['sizeBytes'] as num? ?? 0).toInt(),
      notes: data['notes'] as String?,
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  PetDocumentModel.fromEntity(PetDocument d)
      : super(
          id: d.id,
          householdId: d.householdId,
          petId: d.petId,
          title: d.title,
          category: d.category,
          fileUrl: d.fileUrl,
          mimeType: d.mimeType,
          sizeBytes: d.sizeBytes,
          notes: d.notes,
          createdAt: d.createdAt,
          createdBy: d.createdBy,
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
      'title': title,
      'category': category.name,
      'fileUrl': fileUrl,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  static DocumentCategory _categoryFromString(String? raw) =>
      DocumentCategory.values.firstWhere(
        (c) => c.name == raw,
        orElse: () => DocumentCategory.other,
      );
}
